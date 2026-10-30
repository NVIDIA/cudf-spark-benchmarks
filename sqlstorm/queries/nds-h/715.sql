WITH CTE_Supplier_Sales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        RANK() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CTE_Customer_Spend AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS purchase_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
CTE_Nation_Info AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(s.s_acctbal) AS total_balance
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)

SELECT 
    ns.n_name,
    ss.s_name,
    ss.total_sales,
    cs.total_spent,
    COALESCE(cs.total_spent, 0) - COALESCE(ss.total_sales, 0) AS net_difference
FROM 
    CTE_Nation_Info ns
LEFT JOIN 
    CTE_Supplier_Sales ss ON ns.n_nationkey = ss.s_suppkey
FULL OUTER JOIN 
    CTE_Customer_Spend cs ON ns.n_nationkey = cs.c_custkey
WHERE 
    (ss.total_sales IS NOT NULL OR cs.total_spent IS NOT NULL)
    AND (ns.total_balance > 10000 OR ss.total_sales IS NULL)
ORDER BY 
    net_difference DESC, ns.n_name ASC;

