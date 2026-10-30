WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
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
        o.o_totalprice, 
        c.c_name AS customer_name,
        l.l_shipmode, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_value
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' AND 
        l.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_totalprice, c.c_name, l.l_shipmode
)
SELECT 
    r.nation,
    AVG(hv.net_value) AS avg_order_value,
    COUNT(distinct hv.o_orderkey) AS number_of_orders,
    MAX(r.total_cost) AS max_supplier_cost
FROM 
    RankedSuppliers r
JOIN 
    HighValueOrders hv ON r.nation = hv.customer_name
GROUP BY 
    r.nation
HAVING 
    COUNT(distinct hv.o_orderkey) > 5
ORDER BY 
    avg_order_value DESC;