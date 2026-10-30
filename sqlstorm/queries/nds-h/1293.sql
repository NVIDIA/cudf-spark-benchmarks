WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O' AND
        o.o_orderdate >= '1996-01-01' 
),
HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
OrdersWithDiscount AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS discounted_total
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
),
FinalReport AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        pp.p_name,
        pp.p_retailprice,
        sp.s_name,
        sp.n_name AS supplier_nation,
        COALESCE(olv.discounted_total, 0) AS order_discounted_total,
        COALESCE(hvp.total_supply_cost, 0) AS high_value_supply_cost
    FROM 
        RankedOrders ro
    LEFT JOIN 
        lineitem l ON ro.o_orderkey = l.l_orderkey
    LEFT JOIN 
        part pp ON l.l_partkey = pp.p_partkey 
    LEFT JOIN 
        SupplierInfo sp ON l.l_suppkey = sp.s_suppkey AND sp.rank = 1
    LEFT JOIN 
        OrdersWithDiscount olv ON ro.o_orderkey = olv.l_orderkey
    LEFT JOIN 
        HighValueParts hvp ON pp.p_partkey = hvp.ps_partkey
)
SELECT 
    f.o_orderkey, 
    f.o_orderdate, 
    f.o_totalprice, 
    f.c_name, 
    f.p_name, 
    f.p_retailprice,
    f.s_name,
    f.supplier_nation,
    f.order_discounted_total,
    f.high_value_supply_cost
FROM 
    FinalReport f
WHERE 
    f.o_totalprice > 1000 
ORDER BY 
    f.o_orderdate DESC, 
    f.o_totalprice DESC;