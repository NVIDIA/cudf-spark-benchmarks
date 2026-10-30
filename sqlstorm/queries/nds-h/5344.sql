WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierOrderValues AS (
    SELECT 
        rs.nation,
        h.o_orderkey,
        h.order_value,
        ROW_NUMBER() OVER (PARTITION BY rs.nation ORDER BY h.order_value DESC) AS order_rank
    FROM 
        RankedSuppliers rs
    JOIN 
        lineitem l ON rs.s_suppkey = l.l_suppkey
    JOIN 
        HighValueOrders h ON l.l_orderkey = h.o_orderkey
)
SELECT 
    nation,
    COUNT(o_orderkey) AS total_high_value_orders,
    AVG(order_value) AS avg_order_value,
    MIN(order_value) AS min_order_value,
    MAX(order_value) AS max_order_value
FROM 
    SupplierOrderValues
WHERE 
    order_rank <= 10
GROUP BY 
    nation
ORDER BY 
    nation;
