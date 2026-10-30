WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM
        orders o
    WHERE
        o.o_orderdate >= DATE '1996-01-01'
),
SupplierAggregates AS (
    SELECT
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM
        partsupp ps
    INNER JOIN
        part p ON ps.ps_partkey = p.p_partkey
    WHERE
        p.p_retailprice > 100
    GROUP BY
        ps.ps_suppkey
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        c.c_acctbal > 500
    GROUP BY
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        sa.total_supply_value,
        RANK() OVER (ORDER BY sa.total_supply_value DESC) AS supplier_rank
    FROM
        supplier s
    LEFT JOIN
        SupplierAggregates sa ON s.s_suppkey = sa.ps_suppkey
)
SELECT
    COALESCE(co.c_name, 'Unknown Customer') AS customer_name,
    COALESCE(ts.s_name, 'Unknown Supplier') AS supplier_name,
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    co.order_count,
    co.total_spent,
    ts.total_supply_value
FROM
    RankedOrders ro
LEFT JOIN
    CustomerOrders co ON ro.o_orderkey = co.order_count
LEFT JOIN
    lineitem li ON ro.o_orderkey = li.l_orderkey
FULL OUTER JOIN
    TopSuppliers ts ON li.l_suppkey = ts.s_suppkey
WHERE
    (ro.o_orderdate BETWEEN '1996-01-01' AND cast('1998-10-01' as date) OR ro.o_orderkey IS NULL)
    AND (co.total_spent IS NOT NULL OR ts.total_supply_value IS NOT NULL)
ORDER BY
    ro.o_orderdate DESC, ts.total_supply_value DESC;