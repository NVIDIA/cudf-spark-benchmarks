WITH RecursiveTaxCalc AS (
    SELECT
        l_orderkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_price,
        COUNT(*) AS line_count
    FROM
        lineitem
    WHERE
        l_returnflag = 'A'
    GROUP BY
        l_orderkey
),
RegionalActivity AS (
    SELECT
        r.r_regionkey,
        n.n_name,
        SUM(o.o_totalprice) AS total_region_sales
    FROM
        region r
    JOIN
        nation n ON n.n_regionkey = r.r_regionkey
    JOIN
        supplier s ON s.s_nationkey = n.n_nationkey
    JOIN
        partsupp ps ON ps.ps_suppkey = s.s_suppkey
    JOIN
        lineitem l ON l.l_partkey = ps.ps_partkey
    JOIN
        orders o ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderstatus IN ('F', 'O')
    GROUP BY
        r.r_regionkey, n.n_name
),
CustomerSegment AS (
    SELECT 
        c.c_mktsegment,
        COUNT(DISTINCT c.c_custkey) AS cust_count,
        AVG(c.c_acctbal) AS avg_acct_balance
    FROM 
        customer c
    GROUP BY 
        c.c_mktsegment
)
SELECT 
    r.n_name,
    ROUND(r.total_region_sales, 2) AS region_sales,
    COALESCE(cs.cust_count, 0) AS customer_count,
    cs.avg_acct_balance,
    COUNT(DISTINCT t.l_orderkey) FILTER (WHERE t.total_price > 100) AS high_value_orders,
    (SELECT COUNT(*) FROM orders WHERE o_orderdate >= cast('1998-10-01' as date) - INTERVAL '30 days' AND o_orderdate < cast('1998-10-01' as date)) AS recent_orders
FROM 
    RegionalActivity r
LEFT JOIN 
    CustomerSegment cs ON r.n_name LIKE '%' || cs.c_mktsegment || '%'
LEFT JOIN 
    RecursiveTaxCalc t ON t.l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_orderstatus = 'O')
GROUP BY 
    r.n_name, r.total_region_sales, cs.cust_count, cs.avg_acct_balance
HAVING 
    SUM(r.total_region_sales) > (SELECT AVG(total_region_sales) FROM RegionalActivity) OR
    MAX(cs.avg_acct_balance) IS NULL
ORDER BY 
    region_sales DESC,
    customer_count DESC NULLS FIRST;