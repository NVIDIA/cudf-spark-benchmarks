
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
),
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL 
    GROUP BY 
        s.s_suppkey
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS orders_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    COALESCE(cs.s_suppkey, 0) AS supplier_id,
    cj.c_custkey,
    cj.c_name,
    COALESCE(o.order_rank, 0) AS order_rank,
    cs.total_parts,
    cs.total_supply_cost,
    cj.orders_count,
    cj.total_spent,
    CASE 
        WHEN cj.total_spent IS NULL OR cj.total_spent = 0 THEN 'NO ORDERS'
        WHEN cj.total_spent BETWEEN 1000 AND 5000 THEN 'MID SPENDER'
        WHEN cj.total_spent > 5000 THEN 'HIGH SPENDER'
        ELSE 'UNKNOWN'
    END AS spender_category
FROM 
    supplier_summary cs
FULL OUTER JOIN 
    ranked_orders o ON cs.s_suppkey = o.o_orderkey
FULL OUTER JOIN 
    customer_orders cj ON cs.s_suppkey = cj.c_custkey
WHERE 
    (cs.total_supply_cost IS NULL OR cs.total_parts > 10)
    AND (cj.orders_count > 0 OR o.order_rank IS NOT NULL)
ORDER BY 
    COALESCE(cj.total_spent, 0) DESC, 
    COALESCE(cs.total_supply_cost, 0) ASC
LIMIT 100;
