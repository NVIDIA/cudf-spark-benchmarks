WITH ranked_parts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
), 
customer_orders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    WHERE 
        o.o_orderdate >= '1996-01-01' 
        AND o.o_orderdate < '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
), 
supplier_part_data AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    WHERE 
        s.s_acctbal IS NOT NULL 
        AND s.s_acctbal > 100
    GROUP BY 
        s.s_suppkey, s.s_name, ps.ps_partkey
)

SELECT 
    co.c_name AS customer_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COALESCE(SUM(li.l_extendedprice * (1 - li.l_discount)), 0) AS total_revenue,
    p.p_name AS most_expensive_part,
    p.p_retailprice AS max_price,
    COALESCE(sp.total_avail_qty, 0) AS available_quantity,
    RANK() OVER (ORDER BY COALESCE(SUM(li.l_extendedprice * (1 - li.l_discount)), 0) DESC) AS revenue_rank
FROM 
    customer_orders co
LEFT JOIN 
    orders o ON co.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem li ON o.o_orderkey = li.l_orderkey
LEFT JOIN 
    ranked_parts p ON p.rn = 1
LEFT JOIN 
    supplier_part_data sp ON sp.ps_partkey = p.p_partkey
WHERE 
    co.total_spent > (SELECT AVG(total_spent) FROM customer_orders)
    AND p.p_retailprice IS NOT NULL
GROUP BY 
    co.c_name, p.p_name, p.p_retailprice, sp.total_avail_qty
HAVING 
    SUM(li.l_tax) < 5000
ORDER BY 
    revenue_rank;