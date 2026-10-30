WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
top_orders AS (
    SELECT 
        nation_name,
        o_orderkey,
        o_orderdate,
        o_totalprice,
        c_name
    FROM 
        ranked_orders
    WHERE 
        rank <= 5
)
SELECT 
    t.nation_name,
    COUNT(t.o_orderkey) AS order_count,
    AVG(t.o_totalprice) AS avg_order_value,
    SUM(p.ps_supplycost * li.l_quantity) AS total_supply_cost
FROM 
    top_orders t
JOIN 
    lineitem li ON t.o_orderkey = li.l_orderkey
JOIN 
    partsupp p ON li.l_partkey = p.ps_partkey
GROUP BY 
    t.nation_name
ORDER BY 
    order_count DESC, avg_order_value DESC;