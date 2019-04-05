/***************************************************************************************
Name      : TBD
License   : TBD
            TBD
****************************************************************************************
DESCRIPTION / NOTES:
- TBD
****************************************************************************************
PREREQUISITES:
- nu_park.tables execution and data load
- ERROR HANDLING
***************************************************************************************/

/*  GENERAL CONFIGURATION AND SETUP ***************************************************/
PRINT '** General Configuration & Setup';
/*  Change database context to the specified database in SQL Server. 
    https://docs.microsoft.com/en-us/sql/t-sql/language-elements/use-transact-sql */
USE dw_db;
GO

/*  Specify ISO compliant behavior of the Equals (=) and Not Equal To (<>) comparison
    operators when they are used with null values.
    https://docs.microsoft.com/en-us/sql/t-sql/statements/set-ansi-nulls-transact-sql
    -   When SET ANSI_NULLS is ON, a SELECT statement that uses WHERE column_name = NULL 
        returns zero rows even if there are null values in column_name. A SELECT 
        statement that uses WHERE column_name <> NULL returns zero rows even if there 
        are nonnull values in column_name. 
    -   When SET ANSI_NULLS is OFF, the Equals (=) and Not Equal To (<>) comparison 
        operators do not follow the ISO standard. A SELECT statement that uses WHERE 
        column_name = NULL returns the rows that have null values in column_name. A 
        SELECT statement that uses WHERE column_name <> NULL returns the rows that 
        have nonnull values in the column. Also, a SELECT statement that uses WHERE 
        column_name <> XYZ_value returns all rows that are not XYZ_value and that are 
        not NULL. */
SET ANSI_NULLS ON;
GO

/*  Causes SQL Server to follow  ISO rules regarding quotation mark identifiers &
    literal strings.
    https://docs.microsoft.com/en-us/sql/t-sql/statements/set-quoted-identifier-transact-sql
    -   When SET QUOTED_IDENTIFIER is ON, identifiers can be delimited by double 
        quotation marks, and literals must be delimited by single quotation marks. When 
        SET QUOTED_IDENTIFIER is OFF, identifiers cannot be quoted and must follow all 
        Transact-SQL rules for identifiers. */
SET QUOTED_IDENTIFIER ON;
GO

/*  DELETE EXISTING OBJECTS ***********************************************************/
PRINT '** Delete Existing Objects';
GO

BEGIN TRY
    DECLARE @SQL NVARCHAR(MAX) = '';
    DECLARE @schemaName NVARCHAR(128) = '';
    DECLARE @objectName NVARCHAR(128) = '';
    DECLARE @objectType NVARCHAR(1) = '';
    DECLARE @localCounter INTEGER = 0;
    DECLARE @loopMe BIT = 1;

    WHILE @loopMe = 1
    BEGIN

        SET @schemaName = 'nu_park'
        SET @localCounter = @localCounter + 1

        IF @localCounter = 1
        BEGIN
            SET @objectName ='match_tx'
            SET @objectType = 'P'
        END
        ELSE IF @localCounter = 2
        BEGIN
            SET @objectName ='tx_match_a'
            SET @objectType = 'V'
        END
        ELSE IF @localCounter = 3
        BEGIN
            SET @objectName ='tx_match_b'
            SET @objectType = 'V'
        END
        ELSE IF @localCounter = 4
        BEGIN
            SET @objectName ='transaction_mod'
            SET @objectType = 'U'
        END
        ELSE IF @localCounter = 5
        BEGIN
            SET @objectName ='transaction_f'
            SET @objectType = 'U'
        END
        ELSE SET @loopMe = 0

        IF @objectType = 'U' SET @SQL = 'TABLE'
        ELSE IF @objectType = 'P' SET @SQL = 'PROCEDURE'
        ELSE IF @objectType = 'V' SET @SQL = 'VIEW'
        ELSE SET @loopMe = 0

        SET @SQL = 'DROP ' + @SQL + ' ' + @schemaName + '.' + @objectName

        IF @loopMe = 1 AND OBJECT_ID(@schemaName + '.' + @objectName,@objectType) IS NOT NULL
        BEGIN
            BEGIN TRY
                PRINT @SQL
                EXEC(@SQL)
            END TRY
            BEGIN CATCH
                EXEC dbo.PrintError
                EXEC dbo.LogError
            END CATCH
        END

    END
END TRY
BEGIN CATCH
    IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
    IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
END CATCH

/*  PROCEDURE CREATION ****************************************************************/
PRINT '** CREATE VIEW';
GO

CREATE VIEW nu_park.tx_match_a
            AS
            SELECT  m.uuid,
                    m.meter_type,
                    m.pole_id,
                    m.amount_usd,
                    m.pmt_method_id,
                    m.tx_fileyear,
                    (CASE WHEN m.trans_start <= n.trans_start THEN m.trans_start
                                                              ELSE n.trans_start 
                    END) AS new_trans_start,
                    (CASE WHEN m.trans_end >= n.trans_end THEN m.trans_end
                                                          ELSE n.trans_end
                    END) AS new_trans_end
            FROM    nu_park.transactions AS m 
                    INNER JOIN nu_park.transactions AS n ON m.pole_id = n.pole_id
                                                            AND ((n.trans_start >= m.trans_start AND n.trans_start <= n.trans_end)
                                                            OR (n.trans_end >= m.trans_start AND n.trans_end <= m.trans_end))
                    ;
GO

CREATE VIEW nu_park.tx_match_b
            AS
            SELECT  d.uuid,
                    d.meter_type,
                    d.pole_id,
                    d.amount_usd,
                    d.pmt_method_id,
                    d.tx_fileyear,
                    MIN(new_trans_start) AS min_trans_start,
                    MAX(new_trans_end) AS max_trans_end
            FROM    nu_park.tx_match_a AS d
            GROUP BY    d.uuid,
                        d.meter_type,
                        d.pole_id,
                        d.amount_usd,
                        d.pmt_method_id,
                        d.tx_fileyear
            ;
GO

/*  MAKE FINAL TABLE ******************************************************************/
PRINT '** CREATE FINAL TABLE';
GO

SELECT  d.meter_type,
        d.pole_id,
        SUM(d.amount_usd) AS total_amt_usd,
        d.pmt_method_id,
        d.tx_fileyear,
        d.min_trans_start AS trans_start,
        d.max_trans_end AS trans_end
INTO    nu_park.transaction_mod
FROM    nu_park.tx_match_b AS d
GROUP BY    d.meter_type,
            d.pole_id,
            d.pmt_method_id,
            d.tx_fileyear,
            d.min_trans_start,
            d.max_trans_end;
GO

/*  MAKE FINAL VIEW *******************************************************************/
PRINT '** CREATE FINAL VIEW';
GO

CREATE VIEW nu_park.transaction_f
            AS
            SELECT  d.meter_type,
                    d.pole_id,
                    l.zone_type,
                    l.area,
                    l.sub_area,
                    l.config_code,
                    c.config_name,
                    l.latitude,
                    l.longitude, 
                    d.total_amt_usd,
                    d.pmt_method_id,
                    p.pmt_method_name,
                    d.tx_fileyear,
                    d.trans_start,
                    d.trans_end
            FROM    nu_park.transaction_mod AS d
                    LEFT JOIN nu_park.locations AS l ON d.pole_id = l.pole_id 
                    LEFT JOIN nu_park.configcodes AS c ON l.config_code = c.config_code
                    LEFT JOIN nu_park.pmtmethods AS p ON d.pmt_method_id = p.pmt_method_id
                    ;
GO
