
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(ro.total_price) AS customer_spent
    FROM 
        customer c
    JOIN 
        RecentOrders ro ON c.c_custkey = ro.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(ro.total_price) > 100000
)
SELECT 
    rc.r_name AS region_name,
    COUNT(DISTINCT TOPC.c_custkey) AS top_customers_count,
    SUM(RS.total_cost) AS suppliers_total_cost
FROM 
    region rc
LEFT JOIN 
    nation n ON rc.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    RankedSuppliers RS ON s.s_suppkey = RS.s_suppkey
LEFT JOIN 
    TopCustomers TOPC ON TOPC.c_custkey = s.s_nationkey
WHERE 
    RS.rank <= 5 OR RS.rank IS NULL
GROUP BY 
    rc.r_name
ORDER BY 
    top_customers_count DESC, suppliers_total_cost DESC;
