WITH  orders_cte AS (
    SELECT 
        o_orderkey, 
        o_custkey, 
        o_orderdate, 
        o_totalprice,
        o_shippriority,
        ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) as rn
    FROM 
        orders
    WHERE 
        o_orderstatus = 'O'
),
supplier_totals AS (
    SELECT 
        ps_partkey, 
        SUM(ps_supplycost * ps_availqty) AS total_supply_cost
    FROM 
        partsupp 
    GROUP BY 
        ps_partkey
),
high_spenders AS (
    SELECT 
        c_custkey, 
        c_name, 
        SUM(o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c_custkey, c_name
    HAVING 
        SUM(o_totalprice) > 10000
),
lineitem_summary AS (
    SELECT 
        l_orderkey, 
        SUM(l_extendedprice) AS total_extended_price,
        AVG(l_discount) AS avg_discount
    FROM 
        lineitem
    GROUP BY 
        l_orderkey
)
SELECT 
    o.rn,
    o.o_orderkey,
    o.o_orderdate,
    coalesce(ls.total_extended_price, 0) AS total_extended_price,
    ht.total_spent,
    st.total_supply_cost,
    (o.o_totalprice - coalesce(ls.total_extended_price, 0)) AS price_variance
FROM 
    orders_cte o
LEFT JOIN 
    lineitem_summary ls ON o.o_orderkey = ls.l_orderkey
LEFT JOIN 
    high_spenders ht ON o.o_custkey = ht.c_custkey
JOIN 
    supplier_totals st ON EXISTS (
        SELECT 1 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (SELECT p_partkey FROM part WHERE p_retailprice < 100)
        AND ps.ps_supplycost = st.total_supply_cost
    )
WHERE 
    o.o_orderdate > '1997-01-01' 
    AND o.o_shippriority > 0
ORDER BY 
    o.o_orderdate DESC, price_variance ASC;