
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderstatus IN ('O', 'F')
), SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), OrderLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        CASE 
            WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount)
            ELSE l.l_extendedprice
        END AS effective_price
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '1997-02-01' AND DATE '1997-03-01'
), CustomerNations AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        c.c_acctbal
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        c.c_acctbal IS NOT NULL
), FinalResults AS (
    SELECT 
        r.o_orderkey,
        r.o_orderstatus,
        r.o_orderdate,
        COALESCE(SUM(l.effective_price), 0) AS total_lineitem_value,
        COALESCE(SUM(sp.total_available), 0) AS total_available_parts,
        cn.nation_name
    FROM 
        RankedOrders r
    LEFT JOIN 
        OrderLineItems l ON r.o_orderkey = l.l_orderkey
    LEFT JOIN 
        SupplierParts sp ON l.l_partkey = sp.ps_partkey
    LEFT JOIN 
        CustomerNations cn ON r.o_orderkey = cn.c_custkey
    GROUP BY 
        r.o_orderkey, r.o_orderstatus, r.o_orderdate, cn.nation_name
    HAVING 
        COALESCE(SUM(l.effective_price), 0) > 5000 
        OR COALESCE(SUM(sp.total_available), 0) = 0
)
SELECT 
    fr.o_orderkey,
    fr.o_orderstatus,
    fr.o_orderdate,
    fr.total_lineitem_value,
    fr.total_available_parts,
    fr.nation_name
FROM 
    FinalResults fr
WHERE 
    fr.nation_name IS NOT NULL
ORDER BY 
    fr.total_lineitem_value DESC, 
    fr.o_orderdate ASC
LIMIT 100;
