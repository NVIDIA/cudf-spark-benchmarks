WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderstatus, 
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate <= DATE '1996-12-31'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name
    FROM 
        supplier s 
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
AggregateLineItems AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' 
        AND l.l_shipdate <= DATE '1996-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    oo.o_orderkey, 
    oo.o_orderdate, 
    oo.o_totalprice, 
    oo.o_orderstatus, 
    SUM(ali.total_revenue) AS total_revenue, 
    COUNT(DISTINCT sd.s_suppkey) AS supplier_count
FROM 
    RankedOrders oo
JOIN 
    AggregateLineItems ali ON oo.o_orderkey = ali.l_orderkey
JOIN 
    partsupp ps ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 10)
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
WHERE 
    oo.order_rank <= 5
GROUP BY 
    oo.o_orderkey, 
    oo.o_orderdate, 
    oo.o_totalprice, 
    oo.o_orderstatus
ORDER BY 
    total_revenue DESC;