
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' 
        AND o.o_orderdate < DATE '1995-12-31'
), HighValueLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax
    FROM 
        lineitem l
    JOIN 
        RankedOrders ro ON l.l_orderkey = ro.o_orderkey
    WHERE 
        ro.rank <= 10
), SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(p.ps_supplycost * h.l_extendedprice * (1 - h.l_discount)) AS total_cost
    FROM 
        partsupp p
    JOIN 
        HighValueLineItems h ON p.ps_partkey = h.l_partkey
    JOIN 
        supplier s ON p.ps_suppkey = s.s_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
)
SELECT 
    n.n_name AS supplier_nation,
    COUNT(DISTINCT si.s_suppkey) AS supplier_count,
    SUM(si.total_cost) AS total_supply_cost
FROM 
    SupplierInfo si
JOIN 
    nation n ON si.s_nationkey = n.n_nationkey
GROUP BY 
    n.n_name
ORDER BY 
    total_supply_cost DESC;
