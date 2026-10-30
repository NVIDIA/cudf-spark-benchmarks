
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation,
        COUNT(DISTINCT ps.ps_partkey) AS product_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    sd.s_suppkey,
    sd.s_name,
    sd.nation,
    sd.s_acctbal,
    COALESCE(os.total_revenue, 0) AS total_revenue,
    sd.product_count,
    CASE 
        WHEN sd.product_count > 5 THEN 'High'
        WHEN sd.product_count BETWEEN 3 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS product_supply_level
FROM 
    SupplierDetails sd
LEFT JOIN 
    OrderSummary os ON sd.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_size > 10
        ) 
        ORDER BY ps.ps_supplycost 
        LIMIT 1
    )
ORDER BY 
    sd.s_acctbal DESC, total_revenue DESC;
