WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
), TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.o_orderpriority,
        ro.c_name
    FROM 
        RankedOrders ro
    WHERE 
        ro.rank <= 5
), SupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
), OrderDetails AS (
    SELECT 
        lo.l_orderkey,
        lo.l_partkey,
        lo.l_quantity,
        lo.l_extendedprice,
        si.s_name,
        si.s_acctbal
    FROM 
        lineitem lo
    JOIN 
        SupplierInfo si ON lo.l_suppkey = si.ps_suppkey
    WHERE 
        lo.l_orderkey IN (SELECT o_orderkey FROM TopOrders)
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    od.l_partkey,
    od.l_quantity,
    od.l_extendedprice,
    si.s_name AS supplier_name,
    si.s_acctbal AS supplier_balance,
    o.o_orderpriority
FROM 
    TopOrders o
JOIN 
    OrderDetails od ON o.o_orderkey = od.l_orderkey
JOIN 
    SupplierInfo si ON od.l_partkey = si.ps_partkey
ORDER BY 
    o.o_orderdate DESC, o.o_totalprice DESC;