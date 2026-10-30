WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_availqty) DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name AS customer_name,
        n.n_name AS nation_name
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
)
SELECT 
    R.nation_name,
    R.s_name,
    R.total_available_quantity,
    R.total_supply_cost,
    COUNT(DISTINCT O.o_orderkey) AS total_orders,
    SUM(O.o_totalprice) AS total_order_value
FROM 
    RankedSuppliers R
LEFT JOIN 
    HighValueOrders O ON R.nation_name = O.nation_name
WHERE 
    R.rank_within_nation <= 5
GROUP BY 
    R.nation_name, R.s_name, R.total_available_quantity, R.total_supply_cost
ORDER BY 
    R.nation_name, total_order_value DESC;
