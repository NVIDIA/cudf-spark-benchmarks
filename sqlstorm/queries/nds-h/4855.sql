WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS unique_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
RankedOrders AS (
    SELECT 
        co.c_custkey,
        co.total_orders,
        co.total_spent,
        DENSE_RANK() OVER (ORDER BY co.total_spent DESC) AS rank_spent
    FROM 
        CustomerOrders co
),
FinalResult AS (
    SELECT 
        n.n_name,
        ss.s_suppkey,
        ss.total_avail_qty,
        ss.avg_supply_cost,
        ro.total_orders,
        ro.total_spent,
        ro.rank_spent
    FROM 
        SupplierStats ss
    LEFT JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        RankedOrders ro ON s.s_suppkey = ro.c_custkey
    WHERE 
        (ro.total_orders IS NOT NULL AND ro.total_orders > 10) OR ro.total_spent IS NULL
    ORDER BY 
        total_spent DESC, total_avail_qty ASC
)
SELECT 
    f.n_name,
    f.s_suppkey,
    f.total_avail_qty,
    f.avg_supply_cost,
    f.total_orders,
    f.total_spent,
    f.rank_spent
FROM 
    FinalResult f
WHERE 
    f.rank_spent <= 10 OR f.total_orders IS NULL;
