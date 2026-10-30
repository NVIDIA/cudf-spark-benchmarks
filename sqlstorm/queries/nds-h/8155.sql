WITH ranked_orders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey 
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
top_orders AS (
    SELECT 
        o_orderkey, 
        o_orderdate, 
        total_revenue 
    FROM 
        ranked_orders 
    WHERE 
        order_rank <= 10
),
supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        p.p_name AS part_name,
        ps.ps_supplycost
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey 
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    SUM(sd.ps_supplycost) AS total_supply_cost,
    COUNT(sd.s_suppkey) AS total_suppliers,
    MAX(sd.nation_name) AS supplier_nation,
    MAX(s_total.total_revenue) AS revenue_from_orders
FROM 
    top_orders o
JOIN 
    supplier_details sd ON o.o_orderkey = sd.s_suppkey
JOIN 
    (SELECT 
         o_orderkey, 
         total_revenue 
     FROM 
         ranked_orders) s_total ON o.o_orderkey = s_total.o_orderkey
GROUP BY 
    o.o_orderkey, o.o_orderdate
ORDER BY 
    total_supply_cost DESC, revenue_from_orders DESC;
