WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        s.s_acctbal > 5000 
        AND o.o_orderdate BETWEEN '1995-01-01' AND '1995-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_supply_cost,
        ss.total_orders,
        ss.avg_order_value,
        RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS supplier_rank
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
)
SELECT 
    ts.supplier_rank,
    ts.s_name,
    ts.total_supply_cost,
    ts.total_orders,
    ts.avg_order_value
FROM 
    TopSuppliers ts
WHERE 
    ts.supplier_rank <= 10
ORDER BY 
    ts.supplier_rank;