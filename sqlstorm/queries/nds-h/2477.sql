
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
),

TopOrders AS (
    SELECT
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice
    FROM RankedOrders ro
    WHERE ro.order_rank <= 10
),

SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),

AggregateLineItem AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        SUM(l.l_quantity) AS total_quantity
    FROM lineitem l
    GROUP BY l.l_orderkey
)

SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.o_totalprice,
    sd.s_name AS supplier_name,
    sd.nation_name,
    al.total_quantity,
    COALESCE(sd.supplied_parts, 0) AS parts_supplied
FROM TopOrders t
LEFT JOIN AggregateLineItem al ON t.o_orderkey = al.l_orderkey
LEFT JOIN (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
) psinfo ON psinfo.ps_partkey = al.l_orderkey
LEFT JOIN SupplierDetails sd ON sd.supplied_parts > 0
ORDER BY t.o_totalprice DESC, sd.s_acctbal DESC;
