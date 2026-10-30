WITH RevenueBySupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-12-31'
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
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cs.c_name,
    cs.total_spent AS customer_spent,
    rs.total_revenue AS supplier_revenue,
    (cs.total_spent / NULLIF(rs.total_revenue, 0)) AS spending_to_revenue_ratio
FROM 
    CustomerOrders cs
JOIN 
    RevenueBySupplier rs ON rs.total_revenue > 0
ORDER BY 
    spending_to_revenue_ratio DESC
LIMIT 10;