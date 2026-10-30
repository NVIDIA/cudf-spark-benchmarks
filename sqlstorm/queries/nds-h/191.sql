WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank,
        c.c_name,
        n.n_name AS nation_name
    FROM
        orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE
        o.o_orderstatus IN ('F', 'O')
),
SupplierCosts AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(s.s_suppkey) AS supplier_count
    FROM
        partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY
        ps.ps_partkey
),
HighValueParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(sc.total_cost, 0) AS supply_cost
    FROM
        part p
    LEFT JOIN SupplierCosts sc ON p.p_partkey = sc.ps_partkey
    WHERE
        p.p_retailprice > 100.00
)
SELECT
    r.o_orderkey,
    r.o_orderdate,
    r.c_name,
    r.nation_name,
    h.p_name,
    h.p_retailprice,
    h.supply_cost,
    (h.p_retailprice - h.supply_cost) AS profit_margin,
    CASE 
        WHEN h.supply_cost IS NULL THEN 'No Suppliers'
        ELSE 'Available Suppliers'
    END AS supplier_availability
FROM
    RankedOrders r
JOIN lineitem l ON r.o_orderkey = l.l_orderkey
JOIN HighValueParts h ON l.l_partkey = h.p_partkey
WHERE
    r.order_rank <= 10
    AND l.l_returnflag = 'N'
ORDER BY
    r.o_orderdate DESC,
    r.o_totalprice DESC;
