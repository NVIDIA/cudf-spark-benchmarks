WITH regional_summary AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT c.c_custkey) AS total_customers,
        SUM(o.o_totalprice) AS total_sales,
        AVG(c.c_acctbal) AS avg_account_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        r.r_name
)
SELECT 
    region_name,
    total_customers,
    total_sales,
    avg_account_balance,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM 
    regional_summary
ORDER BY 
    sales_rank
LIMIT 10;