
WITH string_aggregates AS (
    SELECT 
        s.s_name,
        s.s_address,
        s.s_comment,
        CONCAT(SUBSTRING(s.s_name, 1, 5), '...', SUBSTRING(s.s_comment, 1, 10)) AS abbreviated_info,
        LENGTH(s.s_name) AS name_length,
        LENGTH(s.s_address) AS address_length,
        LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000
), 
ranked_suppliers AS (
    SELECT 
        sa.s_name, 
        sa.abbreviated_info,
        sa.name_length,
        sa.address_length,
        sa.comment_length,
        ROW_NUMBER() OVER (ORDER BY sa.name_length DESC, sa.address_length ASC) AS rank
    FROM 
        string_aggregates sa
)
SELECT 
    rs.rank,
    rs.s_name,
    rs.abbreviated_info,
    CONCAT('Length of Name: ', rs.name_length, ', Length of Address: ', rs.address_length, ', Length of Comment: ', rs.comment_length) AS details
FROM 
    ranked_suppliers rs
WHERE 
    rs.rank <= 10
ORDER BY 
    rs.rank;
