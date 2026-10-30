
WITH SupplierCosts AS (
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
CustomerOrders AS (
    SELECT
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey
),
EnhancedLineItems AS (
    SELECT
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        l.l_returnflag,
        l.l_linestatus,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS line_number,
        SUM(l.l_extendedprice) OVER (PARTITION BY l.l_orderkey) AS order_total
    FROM
        lineitem l
)
SELECT
    c.c_custkey,
    COUNT(DISTINCT o.o_orderkey) AS num_orders,
    COALESCE(SUM(li.l_extendedprice * (1 - li.l_discount)), 0) AS total_revenue,
    AVG(CASE WHEN sc.total_supply_cost > 1000 THEN sc.total_supply_cost END) AS avg_high_cost_suppliers,
    r.r_name AS region_name
FROM
    customer c
LEFT JOIN
    CustomerOrders co ON c.c_custkey = co.c_custkey
LEFT JOIN
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN
    EnhancedLineItems li ON o.o_orderkey = li.l_orderkey
LEFT JOIN
    supplier s ON li.l_suppkey = s.s_suppkey
LEFT JOIN
    SupplierCosts sc ON s.s_suppkey = sc.s_suppkey
LEFT JOIN
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    r.r_name IS NOT NULL
GROUP BY
    c.c_custkey, r.r_name
HAVING
    COUNT(DISTINCT o.o_orderkey) >= 1 AND COALESCE(SUM(li.l_extendedprice * (1 - li.l_discount)), 0) > 0
ORDER BY
    total_revenue DESC;
