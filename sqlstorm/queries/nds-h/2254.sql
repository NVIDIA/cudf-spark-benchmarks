
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_in_nation
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT
    cs.c_name AS customer_name,
    ss.s_name AS supplier_name,
    ps.p_name AS part_name,
    ps.total_available,
    ps.avg_supply_cost,
    cs.total_orders,
    cs.total_spent,
    ss.total_supply_cost,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Orders'
        ELSE CONCAT('Ranked ', cs.rank_in_nation, ' in Spending')
    END AS spending_rank_info
FROM 
    CustomerOrderStats cs
LEFT JOIN 
    SupplierStats ss ON cs.total_orders > 10 AND ss.unique_parts > 5
JOIN 
    PartSupplierInfo ps ON ss.s_suppkey = (
        SELECT ps_partkey 
        FROM partsupp 
        WHERE ps_supplycost = (
            SELECT MAX(ps_supplycost) FROM partsupp
        )
        LIMIT 1
    )
WHERE 
    (ps.total_available > 0 OR ps.avg_supply_cost IS NOT NULL)
ORDER BY 
    cs.total_spent DESC, ss.total_supply_cost DESC;
