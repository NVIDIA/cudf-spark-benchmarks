WITH RankedLines AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey, l.l_partkey, l.l_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(rl.total_revenue) AS supplier_revenue
    FROM 
        supplier s
    JOIN 
        RankedLines rl ON s.s_suppkey = rl.l_suppkey
    WHERE 
        rl.revenue_rank <= 5
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cs.c_name,
    cs.total_orders,
    cs.total_spent,
    ts.supplier_revenue
FROM 
    CustomerOrders cs
LEFT JOIN 
    TopSuppliers ts ON ts.supplier_revenue > 10000
ORDER BY 
    cs.total_orders DESC, cs.total_spent DESC
LIMIT 10;
