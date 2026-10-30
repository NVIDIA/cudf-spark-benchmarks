WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supply_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        rs.s_name AS supplier_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_suppkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.supply_rank <= 5
)
SELECT 
    ts.region_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(li.l_extendedprice) AS total_revenue,
    AVG(o.o_totalprice) AS avg_order_price
FROM 
    TopSuppliers ts
JOIN 
    orders o ON ts.supplier_name = o.o_clerk
JOIN 
    lineitem li ON o.o_orderkey = li.l_orderkey
GROUP BY 
    ts.region_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
