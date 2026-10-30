WITH SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartOverview AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        MAX(ps.ps_availqty) AS max_avail_qty
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    po.p_partkey,
    po.p_name,
    po.supplier_count,
    po.avg_supply_cost,
    po.max_avail_qty,
    cs.total_orders,
    cs.total_spent,
    cs.rank_spent,
    CASE 
        WHEN cs.total_orders IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status
FROM 
    PartOverview po
LEFT JOIN 
    CustomerOrderStats cs ON po.supplier_count > 10 
ORDER BY 
    po.avg_supply_cost DESC, cs.total_spent DESC;
