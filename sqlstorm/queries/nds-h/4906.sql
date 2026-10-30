WITH SupplierCost AS (
    SELECT
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey
),
OrderStats AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
        COUNT(l.l_orderkey) AS item_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY
        o.o_orderkey
),
RegionSupplier AS (
    SELECT
        r.r_regionkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM
        region r
    LEFT JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY
        r.r_regionkey
)
SELECT
    r.r_name,
    COALESCE(SC.total_cost, 0) AS total_supplier_cost,
    COALESCE(OS.order_value, 0) AS highest_order_value,
    REGS.supplier_count AS total_suppliers,
    CASE
        WHEN OS.item_count IS NULL THEN 'No Orders'
        ELSE CONCAT('Orders: ', OS.item_count)
    END AS order_information
FROM
    region r
LEFT JOIN
    RegionSupplier REGS ON r.r_regionkey = REGS.r_regionkey
LEFT JOIN
    SupplierCost SC ON SC.s_suppkey IN (SELECT DISTINCT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 20))
LEFT JOIN
    OrderStats OS ON OS.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O' ORDER BY o.o_totalprice DESC LIMIT 1)
ORDER BY
    r.r_name;