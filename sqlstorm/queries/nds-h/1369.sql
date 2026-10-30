WITH SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(s.s_acctbal) AS avg_acct_balance
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_linenumber) AS line_item_count
    FROM
        orders o
    LEFT JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderstatus = 'O' AND
        l.l_returnflag = 'N'
    GROUP BY
        o.o_orderkey, o.o_orderdate
),
TopSuppliers AS (
    SELECT
        sup.s_suppkey,
        sup.s_name,
        RANK() OVER (ORDER BY sup.total_supply_cost DESC) AS rank
    FROM
        SupplierStats sup
    WHERE
        sup.avg_acct_balance > 1000
)
SELECT
    ods.o_orderkey,
    ods.o_orderdate,
    ods.total_order_value,
    ts.s_name AS top_supplier_name,
    ts.rank AS supplier_rank
FROM
    OrderDetails ods
FULL OUTER JOIN
    TopSuppliers ts ON ods.o_orderkey = ts.s_suppkey
WHERE
    (ods.total_order_value > (SELECT AVG(total_order_value) FROM OrderDetails) OR ts.rank IS NOT NULL)
ORDER BY
    ods.o_orderdate DESC, ts.rank ASC;
