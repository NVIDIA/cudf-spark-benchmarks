WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS cost_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.supplier_nation,
        rs.total_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.cost_rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SignificantOrders AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_order_value
    FROM 
        CustomerOrders co
    WHERE 
        co.total_order_value > (SELECT AVG(total_order_value) FROM CustomerOrders)
)
SELECT 
    ts.s_name AS top_supplier_name,
    ts.supplier_nation,
    so.c_name AS significant_customer_name,
    so.total_order_value
FROM 
    TopSuppliers ts
JOIN 
    SignificantOrders so ON ts.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN lineitem li ON ps.ps_partkey = li.l_partkey 
        JOIN orders o ON li.l_orderkey = o.o_orderkey 
        WHERE o.o_totalprice > 10000
    )
ORDER BY 
    ts.total_cost DESC, so.total_order_value DESC;
