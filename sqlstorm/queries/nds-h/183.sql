WITH RegionSummary AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(s.s_acctbal) AS total_account_balance,
        COUNT(DISTINCT c.c_custkey) AS total_customers
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderpriority
)
SELECT 
    rs.r_name,
    rs.total_account_balance,
    rs.total_customers,
    os.o_orderkey,
    os.o_orderdate,
    os.total_sales,
    os.sales_rank
FROM 
    RegionSummary rs
LEFT JOIN 
    (SELECT * FROM OrderStats WHERE sales_rank <= 5) os ON rs.total_account_balance > 2000
WHERE 
    (rs.total_customers > 50 OR rs.total_account_balance IS NULL)
ORDER BY 
    rs.total_account_balance DESC, os.total_sales DESC;
