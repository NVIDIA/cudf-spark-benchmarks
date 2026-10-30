WITH SupplierAggregation AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SalesData AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        o.o_orderdate
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        l.l_orderkey, o.o_orderdate
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    sa.s_name AS supplier_name,
    ca.c_name AS customer_name,
    COALESCE(SUM(sd.revenue), 0) AS total_revenue,
    COALESCE(MAX(ca.total_spent), 0) AS max_customer_spent,
    COALESCE(SUM(sa.total_supply_cost), 0) AS total_supplier_cost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    SupplierAggregation sa ON s.s_suppkey = sa.s_suppkey
LEFT JOIN 
    CustomerOrders ca ON sa.s_suppkey = ca.c_custkey
LEFT JOIN 
    SalesData sd ON ca.c_custkey = sd.l_orderkey
GROUP BY 
    r.r_name, n.n_name, sa.s_name, ca.c_name
ORDER BY 
    total_revenue DESC, max_customer_spent DESC, total_supplier_cost DESC;