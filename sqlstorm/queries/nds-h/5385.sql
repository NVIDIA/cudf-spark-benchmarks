
WITH
    RankedSuppliers AS (
        SELECT
            s.s_suppkey,
            s.s_name,
            s.s_nationkey,
            SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
            RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
        FROM
            supplier s
        JOIN
            partsupp ps ON s.s_suppkey = ps.ps_suppkey
        JOIN
            nation n ON s.s_nationkey = n.n_nationkey
        GROUP BY
            s.s_suppkey, s.s_name, s.s_nationkey, n.n_regionkey
    ),
    ImportantOrders AS (
        SELECT
            o.o_orderkey,
            o.o_totalprice,
            l.l_partkey,
            l.l_quantity,
            l.l_discount,
            l.l_shipdate,
            c.c_name,
            c.c_nationkey
        FROM
            orders o
        JOIN
            lineitem l ON o.o_orderkey = l.l_orderkey
        JOIN
            customer c ON o.o_custkey = c.c_custkey
        WHERE
            o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    )
SELECT
    i.o_orderkey,
    i.o_totalprice,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
    SUM(i.l_quantity * (1 - i.l_discount)) AS net_sales,
    n.n_name AS nation_name,
    rs.s_name AS top_supplier
FROM
    ImportantOrders i
JOIN
    RankedSuppliers rs ON i.l_partkey = rs.s_suppkey
JOIN
    nation n ON i.c_nationkey = n.n_nationkey
WHERE
    rs.rank = 1
GROUP BY
    i.o_orderkey, i.o_totalprice, n.n_name, rs.s_name
ORDER BY
    net_sales DESC
LIMIT 10;
