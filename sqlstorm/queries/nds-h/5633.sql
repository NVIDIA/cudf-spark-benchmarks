WITH SupplierCost AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
RegionStats AS (
    SELECT 
        r.r_regionkey,
        AVG(total_cost) AS avg_supplier_cost,
        MAX(total_spent) AS max_customer_spent
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        SupplierCost sc ON s.s_suppkey = sc.s_suppkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY 
        r.r_regionkey
)
SELECT 
    r.r_name,
    rs.avg_supplier_cost,
    rs.max_customer_spent
FROM 
    region r
JOIN 
    RegionStats rs ON r.r_regionkey = rs.r_regionkey
ORDER BY 
    rs.avg_supplier_cost DESC, rs.max_customer_spent DESC
LIMIT 10;
