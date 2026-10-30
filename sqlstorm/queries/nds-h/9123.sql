
WITH part_supplier AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_availqty,
        ps.ps_supplycost,
        s.s_name AS supplier_name,
        s.s_acctbal
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE
        p.p_retailprice > 100.00
),
customer_orders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        c.c_acctbal > 500.00 AND
        o.o_orderdate >= DATE '1997-01-01'
)
SELECT
    ps.p_name,
    ps.supplier_name,
    COUNT(co.o_orderkey) AS total_orders,
    SUM(co.o_totalprice) AS total_revenue,
    AVG(ps.ps_supplycost) AS average_supply_cost
FROM
    part_supplier ps
LEFT JOIN
    customer_orders co ON ps.p_partkey = co.o_orderkey
GROUP BY
    ps.p_partkey, ps.p_name, ps.supplier_name
HAVING
    COUNT(co.o_orderkey) > 5
ORDER BY
    total_revenue DESC, ps.p_name ASC;
