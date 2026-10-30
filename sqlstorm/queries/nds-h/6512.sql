WITH ranked_orders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_name, 
        n.n_name AS nation, 
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1996-12-31'
), high_value_orders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        ro.nation
    FROM 
        ranked_orders ro 
    JOIN 
        orders o ON ro.o_orderkey = o.o_orderkey
    WHERE 
        ro.rn <= 5
), itemized_orders AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_partkey) AS item_count
    FROM 
        lineitem l
    JOIN 
        high_value_orders hvo ON l.l_orderkey = hvo.o_orderkey
    GROUP BY 
        l.l_orderkey
)
SELECT 
    hvo.o_orderkey, 
    hvo.o_totalprice, 
    hvo.nation, 
    io.total_price AS calculated_total_price, 
    io.item_count 
FROM 
    high_value_orders hvo
JOIN 
    itemized_orders io ON hvo.o_orderkey = io.l_orderkey
WHERE 
    hvo.o_totalprice > io.total_price
ORDER BY 
    hvo.nation, hvo.o_totalprice DESC;