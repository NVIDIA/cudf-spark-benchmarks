WITH ranked_orders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice, 
        o.o_orderdate, 
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
high_value_orders AS (
    SELECT 
        ro.o_orderkey, 
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS net_value
    FROM 
        ranked_orders ro
    JOIN 
        lineitem li ON ro.o_orderkey = li.l_orderkey
    WHERE 
        ro.order_rank <= 10 
    GROUP BY 
        ro.o_orderkey
),
supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
nation_region AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        r.r_regionkey, 
        r.r_name
    FROM 
        nation n 
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name IS NOT NULL OR n.n_comment IS NULL
),
final_report AS (
    SELECT 
        ho.o_orderkey,
        ho.net_value,
        n.n_name AS supplier_nation,
        si.s_name AS supplier_name,
        si.total_supply_cost
    FROM 
        high_value_orders ho
    LEFT JOIN 
        lineitem li ON ho.o_orderkey = li.l_orderkey
    LEFT JOIN 
        supplier_info si ON li.l_suppkey = si.s_suppkey
    JOIN 
        nation_region n ON si.s_suppkey = n.n_nationkey
    WHERE 
        (ho.net_value > 1000 AND si.total_supply_cost IS NOT NULL)
        OR 
        (ho.net_value <= 1000 AND n.n_name LIKE 'A%')
)
SELECT 
    COUNT(*) AS order_count,
    AVG(net_value) AS average_net_value,
    MAX(total_supply_cost) AS max_total_supply_cost,
    MIN(total_supply_cost) AS min_total_supply_cost
FROM 
    final_report
WHERE 
    supplier_nation IS NOT NULL AND supplier_name IS NOT NULL
GROUP BY 
    supplier_nation
HAVING 
    AVG(net_value) > (SELECT AVG(net_value) FROM high_value_orders)
ORDER BY 
    supplier_nation DESC NULLS LAST;