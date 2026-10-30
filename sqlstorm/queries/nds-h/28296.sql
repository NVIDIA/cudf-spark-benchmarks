
WITH RecursiveStringProcessing AS (
    SELECT 
        P.p_partkey,
        P.p_name,
        P.p_comment,
        S.s_name,
        S.s_comment,
        CASE 
            WHEN LENGTH(P.p_name) > 10 THEN SUBSTRING(P.p_name FROM 1 FOR 10) || '...'
            ELSE P.p_name 
        END AS processed_name,
        CASE 
            WHEN POSITION('red' IN P.p_comment) > 0 THEN REPLACE(P.p_comment, 'red', 'blue')
            ELSE P.p_comment 
        END AS processed_comment
    FROM part P
    JOIN partsupp PS ON P.p_partkey = PS.ps_partkey
    JOIN supplier S ON PS.ps_suppkey = S.s_suppkey
),
AggregatedData AS (
    SELECT 
        R.r_name,
        COUNT(DISTINCT R.r_regionkey) AS region_count,
        COUNT(DISTINCT C.c_custkey) AS customer_count,
        COUNT(DISTINCT O.o_orderkey) AS order_count
    FROM region R
    LEFT JOIN nation N ON R.r_regionkey = N.n_regionkey
    LEFT JOIN supplier S ON N.n_nationkey = S.s_nationkey
    LEFT JOIN customer C ON S.s_suppkey = C.c_nationkey
    LEFT JOIN orders O ON C.c_custkey = O.o_custkey
    GROUP BY R.r_name
)
SELECT 
    RSP.processed_name,
    RSP.processed_comment,
    AD.r_name,
    AD.region_count,
    AD.customer_count,
    AD.order_count
FROM RecursiveStringProcessing RSP
JOIN AggregatedData AD ON RSP.p_partkey = AD.region_count
ORDER BY AD.region_count DESC, RSP.processed_name;
