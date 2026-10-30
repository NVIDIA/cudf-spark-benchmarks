WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
), SelectedParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_availability,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size BETWEEN 10 AND 20
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), NationalSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name,
        n.n_regionkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
), FinalReport AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.o_orderstatus,
        ro.c_name,
        ro.c_acctbal,
        np.s_name,
        np.total_cost,
        np.n_name AS supplier_nation
    FROM 
        RankedOrders ro
    JOIN 
        NationalSuppliers np ON ro.o_orderkey % 100 = np.s_suppkey % 100
    WHERE 
        ro.order_rank <= 10
)
SELECT 
    fr.o_orderkey,
    fr.o_orderdate,
    fr.o_totalprice,
    fr.o_orderstatus,
    fr.c_name,
    fr.c_acctbal,
    fr.s_name,
    fr.total_cost,
    fr.supplier_nation
FROM 
    FinalReport fr
ORDER BY 
    fr.o_totalprice DESC;