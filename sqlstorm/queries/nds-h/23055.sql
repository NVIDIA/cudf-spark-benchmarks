
WITH  customer_orders AS (
    SELECT 
        c.c_custkey AS custkey, 
        c.c_name, 
        COALESCE(SUM(o.o_totalprice), 0) AS total_orders,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
supplier_part_info AS (
    SELECT 
        s.s_suppkey AS suppkey,
        s.s_name,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL AND
        ps.ps_availqty > 0 AND p.p_retailprice > 10
),
top_nations AS (
    SELECT 
        n.n_name, 
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n 
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey 
    GROUP BY 
        n.n_name
    ORDER BY 
        supplier_count DESC 
    LIMIT 5
)
SELECT 
    co.custkey,
    co.c_name,
    co.total_orders,
    si.suppkey,
    si.s_name,
    si.p_name,
    CASE 
        WHEN si.ps_availqty <= 0 THEN 'Out of Stock'
        ELSE 'In Stock'
    END AS stock_status,
    nt.n_name AS nation_name
FROM 
    customer_orders co
LEFT JOIN 
    supplier_part_info si ON si.ps_supplycost = (SELECT MIN(ps_supplycost) FROM supplier_part_info)
LEFT JOIN 
    top_nations nt ON nt.supplier_count > (SELECT AVG(supplier_count) FROM top_nations)
WHERE 
    (co.order_count > 0 OR co.total_orders IS NULL)
ORDER BY 
    co.total_orders DESC
LIMIT 5 OFFSET 10;
