WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
RankedOrders AS (
    SELECT 
        co.c_custkey,
        co.total_revenue,
        RANK() OVER (PARTITION BY co.c_custkey ORDER BY co.total_revenue DESC) AS revenue_rank
    FROM 
        CustomerOrders co
),
MaxSupplierCost AS (
    SELECT 
        s.s_suppkey,
        s.total_supply_cost,
        RANK() OVER (ORDER BY s.total_supply_cost DESC) AS cost_rank
    FROM 
        SupplierDetails s
)
SELECT 
    cu.c_name,
    su.s_name,
    su.region_name,
    co.total_revenue,
    s.total_supply_cost,
    CASE 
        WHEN co.total_revenue > 10000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    RankedOrders co
JOIN 
    customer cu ON co.c_custkey = cu.c_custkey
JOIN 
    MaxSupplierCost s ON s.cost_rank = 1
JOIN 
    SupplierDetails su ON s.s_suppkey = su.s_suppkey
WHERE 
    s.total_supply_cost IS NOT NULL
    AND co.revenue_rank = 1
ORDER BY 
    co.total_revenue DESC, su.total_supply_cost DESC;
