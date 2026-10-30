WITH  price_summary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(ps.ps_suppkey) AS supplier_count,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
best_supplier AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        s.s_name,
        ROW_NUMBER() OVER (PARTITION BY l.l_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS supplier_rank
    FROM 
        lineitem l
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    GROUP BY 
        l.l_orderkey, l.l_partkey, s.s_name
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    ps.total_supply_cost,
    cs.total_orders,
    cs.total_spent,
    COALESCE(bs.s_name, 'No Supplier') AS best_supplier_name,
    CASE 
        WHEN cs.total_spent IS NULL OR cs.total_spent = 0 THEN 'Inactive Customer'
        ELSE 'Active Customer'
    END AS customer_status
FROM 
    part p
LEFT JOIN 
    price_summary ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    customer_orders cs ON cs.rank_spent <= 10
LEFT JOIN 
    best_supplier bs ON p.p_partkey = bs.l_partkey AND bs.supplier_rank = 1
WHERE 
    ps.total_supply_cost IS NOT NULL
ORDER BY 
    total_supply_cost DESC, total_spent DESC;
