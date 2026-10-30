
WITH SupplierAggregates AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_availqty) AS total_availqty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_nationkey
), CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
), RankedOrders AS (
    SELECT 
        co.c_custkey,
        co.order_count,
        co.total_spent,
        RANK() OVER (ORDER BY co.total_spent DESC) AS spent_rank
    FROM 
        CustomerOrders co
)
SELECT 
    r.r_name, 
    COUNT(DISTINCT ro.c_custkey) AS customer_count, 
    SUM(sa.total_availqty) AS total_available_parts,
    SUM(sa.total_supplycost) AS total_supply_cost
FROM 
    region r
LEFT JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    SupplierAggregates sa ON s.s_suppkey = sa.s_suppkey
LEFT JOIN 
    RankedOrders ro ON s.s_nationkey = ro.c_custkey
WHERE 
    ro.order_count IS NULL OR ro.spent_rank <= 10
GROUP BY 
    r.r_name
HAVING 
    SUM(sa.total_supplycost) IS NOT NULL
ORDER BY 
    customer_count DESC, 
    total_available_parts ASC;
