WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey, n.n_name
),
TopSuppliers AS (
    SELECT * FROM RankedSuppliers
    WHERE rank <= 3
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        COUNT(li.l_orderkey) AS line_count 
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey 
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
),
SupplierOrderStats AS (
    SELECT 
        ts.nation_name,
        os.o_orderkey,
        os.o_totalprice,
        os.o_orderdate,
        ts.s_name,
        ts.total_cost 
    FROM 
        OrderStats os
    JOIN 
        lineitem li ON os.o_orderkey = li.l_orderkey
    JOIN 
        TopSuppliers ts ON li.l_suppkey = ts.s_suppkey
)
SELECT 
    nation_name,
    s_name,
    COUNT(o_orderkey) AS total_orders,
    AVG(o_totalprice) AS avg_order_value,
    SUM(total_cost) AS total_supplied_cost
FROM 
    SupplierOrderStats
GROUP BY 
    nation_name, s_name
ORDER BY 
    nation_name, total_orders DESC, avg_order_value DESC;
