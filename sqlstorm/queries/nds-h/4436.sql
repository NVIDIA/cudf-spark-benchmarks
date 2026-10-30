WITH ranked_order_items AS (
    SELECT
        l.*

        , ROW_NUMBER() OVER (PARTITION BY l_orderkey ORDER BY l_extendedprice DESC) AS rn

    FROM 
        lineitem l
    WHERE 
        l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
        AND l_discount > 0.1
),

supplier_totals AS (
    SELECT
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        partsupp ps
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY
        ps.ps_suppkey
),

customer_orders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        c.c_acctbal > 1000
    GROUP BY
        c.c_custkey
)

SELECT
    n.n_name AS nation,
    COUNT(DISTINCT co.c_custkey) AS total_customers,
    SUM(rk.l_extendedprice) AS total_revenue,
    SUM(st.total_supply_cost) AS total_supplier_costs
FROM 
    nation n
LEFT JOIN 
    customer_orders co ON n.n_nationkey = co.c_custkey
LEFT JOIN 
    ranked_order_items rk ON co.order_count > 5 AND rk.rn <= 3
LEFT JOIN 
    supplier_totals st ON co.c_custkey = st.ps_suppkey
WHERE 
    n.n_nationkey IS NOT NULL
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC
LIMIT 10;