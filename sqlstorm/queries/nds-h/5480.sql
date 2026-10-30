WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_name AS customer_name,
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        o.o_orderdate BETWEEN '1995-01-01' AND '1995-12-31'
        AND s.s_acctbal > 1000
),
filtered_orders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_totalprice,
        ro.customer_name,
        ro.supplier_name,
        ro.part_name
    FROM 
        ranked_orders ro
    WHERE 
        ro.rank = 1
)
SELECT 
    fo.o_orderkey,
    fo.o_totalprice,
    fo.customer_name,
    fo.supplier_name,
    fo.part_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    COUNT(DISTINCT l.l_orderkey) AS total_orders
FROM 
    filtered_orders fo
JOIN 
    lineitem l ON fo.o_orderkey = l.l_orderkey
GROUP BY 
    fo.o_orderkey, fo.o_totalprice, fo.customer_name, fo.supplier_name, fo.part_name
ORDER BY 
    fo.o_totalprice DESC
LIMIT 100;