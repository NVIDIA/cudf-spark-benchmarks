WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        n.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, n.n_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        c.c_nationkey
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
RegionSummary AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(c.total_spent) AS region_total_spent,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        region r
    LEFT JOIN 
        CustomerOrders c ON r.r_regionkey = c.c_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    r.r_name,
    COALESCE(sp.total_available_qty, 0) AS total_available_qty,
    COALESCE(sp.total_cost, 0) AS total_cost,
    r.region_total_spent,
    r.customer_count
FROM 
    RegionSummary r
LEFT JOIN 
    SupplierDetails sp ON r.r_regionkey = sp.s_nationkey
ORDER BY 
    r.r_name, sp.total_cost DESC;
