WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
),
customer_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
supplier_part AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supplycost,
        MIN(ps.ps_availqty) AS min_avail_qty
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(c.total_spent, 0) AS customer_spending,
    COALESCE(r.order_rank, 0) AS order_rank,
    COALESCE(sp.total_supplycost, 0) AS supplier_cost,
    COALESCE(sp.min_avail_qty, 0) AS min_avail_quantity
FROM 
    part p
LEFT JOIN 
    customer_summary c ON p.p_partkey = c.c_custkey
LEFT JOIN 
    ranked_orders r ON c.order_count > 0 AND r.o_orderkey = c.c_custkey
LEFT JOIN 
    supplier_part sp ON sp.ps_partkey = p.p_partkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
    AND p.p_type LIKE '%plastic%'
ORDER BY 
    p.p_retailprice DESC, 
    customer_spending DESC;